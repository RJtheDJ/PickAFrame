// Tests for firestore.rules against the local Firestore emulator.
// Run with `npm test` in this folder (starts and stops the emulator).
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc, collection, getDocs, query, where } from 'firebase/firestore';

let env;

const design = { artworkMm: { width: 400, height: 300 } };
const finish = { kind: 'wood', id: 'oak' };

const moulding = (id, vendorId, extra = {}) => ({
  id,
  vendorId,
  name: 'Oak 25mm',
  profile: 'flat',
  finish,
  faceWidthMm: 25,
  rebateDepthMm: 12,
  pricePerMetreRm: 31,
  materialClass: 'Wood (Hardwood)',
  ...extra,
});

const order = (id, customerUid, vendorId, extra = {}) => ({
  id,
  draftId: 'd1',
  customerUid,
  vendorId,
  title: 'Sunset',
  specLines: [{ label: 'Artwork', value: '40 × 30 cm' }],
  stage: 'submitted',
  quoteRm: null,
  createdAt: '2026-10-30T00:00:00.000Z',
  ...extra,
});

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-pickaframe',
    firestore: { rules: readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8085 },
  });
});

after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  // Seed with rules off: an artist, a frame shop with its listing, a moulding,
  // a draft and an order.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, 'users/artist'), { uid: 'artist', email: 'a@x.my', displayName: 'Ana', role: 'artist' });
    await setDoc(doc(f, 'users/shop'), { uid: 'shop', email: 's@x.my', displayName: 'Shop', role: 'frameShopOwner', vendorId: 'shop' });
    await setDoc(doc(f, 'users/shop2'), { uid: 'shop2', email: 't@x.my', displayName: 'Shop 2', role: 'frameShopOwner', vendorId: 'shop2' });
    await setDoc(doc(f, 'vendors/shop'), { id: 'shop', ownerUid: 'shop', name: 'Bangsar Frames', address: 'Bangsar', latitude: 3.13, longitude: 101.67 });
    await setDoc(doc(f, 'mouldings/m1'), moulding('m1', 'shop'));
    await setDoc(doc(f, 'drafts/d1'), { id: 'd1', ownerUid: 'artist', title: 'Sunset', design });
    await setDoc(doc(f, 'orders/o1'), order('o1', 'artist', 'shop'));
  });
});

describe('users', () => {
  test('only the owner can read a profile', async () => {
    await assertSucceeds(getDoc(doc(db('artist'), 'users/artist')));
    await assertFails(getDoc(doc(db('shop'), 'users/artist')));
    await assertFails(getDoc(doc(db(null), 'users/artist')));
  });

  test('a new user creates only their own profile', async () => {
    await assertSucceeds(setDoc(doc(db('new'), 'users/new'), { uid: 'new', email: 'n@x.my', displayName: 'N', role: null }));
    await assertFails(setDoc(doc(db('new'), 'users/other'), { uid: 'other', email: 'o@x.my', displayName: 'O' }));
  });

  test('the role is set once and cannot be switched later', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users/fresh'), { uid: 'fresh', email: 'f@x.my', displayName: 'F', role: null }));
    await assertSucceeds(setDoc(doc(db('fresh'), 'users/fresh'), { role: 'artist' }, { merge: true }));
    await assertFails(updateDoc(doc(db('artist'), 'users/artist'), { role: 'frameShopOwner' }));
    await assertFails(updateDoc(doc(db('artist'), 'users/artist'), { email: 'evil@x.my' }));
  });
});

describe('vendors', () => {
  test('anyone can browse the directory', async () => {
    await assertSucceeds(getDocs(collection(db(null), 'vendors')));
  });

  test('a frame shop edits only its own listing', async () => {
    const listing = { id: 'shop2', ownerUid: 'shop2', name: 'Cheras Gilders', address: 'Cheras', latitude: 3.1, longitude: 101.7 };
    await assertSucceeds(setDoc(doc(db('shop2'), 'vendors/shop2'), listing));
    await assertFails(setDoc(doc(db('shop2'), 'vendors/shop'), { ...listing, id: 'shop', ownerUid: 'shop' }));
    await assertFails(setDoc(doc(db('artist'), 'vendors/artist'), { ...listing, id: 'artist', ownerUid: 'artist' }));
  });
});

describe('mouldings', () => {
  test('anyone can browse the catalogue', async () => {
    await assertSucceeds(getDocs(collection(db(null), 'mouldings')));
  });

  test('a frame shop adds and edits only its own mouldings', async () => {
    await assertSucceeds(setDoc(doc(db('shop'), 'mouldings/m2'), moulding('m2', 'shop')));
    await assertFails(setDoc(doc(db('shop2'), 'mouldings/m3'), moulding('m3', 'shop')));
    await assertFails(setDoc(doc(db('artist'), 'mouldings/m4'), moulding('m4', 'artist')));
    await assertFails(updateDoc(doc(db('shop2'), 'mouldings/m1'), { pricePerMetreRm: 1 }));
    await assertFails(deleteDoc(doc(db('shop2'), 'mouldings/m1')));
    await assertSucceeds(deleteDoc(doc(db('shop'), 'mouldings/m1')));
  });

  test('a moulding cannot be handed to another shop', async () => {
    await assertFails(updateDoc(doc(db('shop'), 'mouldings/m1'), { vendorId: 'shop2' }));
  });

  test('invalid values are refused', async () => {
    const bad = [
      { name: '' },
      { pricePerMetreRm: -5 },
      { pricePerMetreRm: 'free' },
      { faceWidthMm: 9999 },
      { materialClass: 'Unobtanium' },
      { name: 'x'.repeat(81) },
    ];
    for (const extra of bad) {
      await assertFails(setDoc(doc(db('shop'), 'mouldings/bad'), moulding('bad', 'shop', extra)));
    }
  });
});

describe('drafts', () => {
  test('only the owner sees their drafts', async () => {
    await assertSucceeds(getDoc(doc(db('artist'), 'drafts/d1')));
    await assertFails(getDoc(doc(db('shop'), 'drafts/d1')));
    await assertSucceeds(getDocs(query(collection(db('artist'), 'drafts'), where('ownerUid', '==', 'artist'))));
    await assertFails(getDocs(collection(db('artist'), 'drafts')));
  });

  test('drafts cannot be written for someone else or stolen', async () => {
    await assertFails(setDoc(doc(db('shop'), 'drafts/d2'), { id: 'd2', ownerUid: 'artist', title: 'x', design }));
    await assertFails(updateDoc(doc(db('artist'), 'drafts/d1'), { ownerUid: 'shop' }));
    await assertFails(updateDoc(doc(db('shop'), 'drafts/d1'), { title: 'mine now' }));
    await assertFails(deleteDoc(doc(db('shop'), 'drafts/d1')));
  });
});

describe('orders', () => {
  test('the customer and the workshop can read an order; nobody else', async () => {
    await assertSucceeds(getDoc(doc(db('artist'), 'orders/o1')));
    await assertSucceeds(getDoc(doc(db('shop'), 'orders/o1')));
    await assertFails(getDoc(doc(db('shop2'), 'orders/o1')));
    await assertFails(getDoc(doc(db(null), 'orders/o1')));
  });

  test('customers place unquoted orders at the first stage, with real workshops', async () => {
    await assertSucceeds(setDoc(doc(db('artist'), 'orders/o2'), order('o2', 'artist', 'shop')));
    await assertFails(setDoc(doc(db('artist'), 'orders/o3'), order('o3', 'artist', 'shop', { quoteRm: 1 })));
    await assertFails(setDoc(doc(db('artist'), 'orders/o4'), order('o4', 'artist', 'shop', { stage: 'completed' })));
    await assertFails(setDoc(doc(db('artist'), 'orders/o5'), order('o5', 'artist', 'nowhere')));
    await assertFails(setDoc(doc(db('artist'), 'orders/o6'), order('o6', 'someone', 'shop')));
  });

  test('only the workshop sets the quote and moves the stage, forwards only', async () => {
    await assertFails(updateDoc(doc(db('artist'), 'orders/o1'), { quoteRm: 1 }));
    await assertFails(updateDoc(doc(db('artist'), 'orders/o1'), { stage: 'completed' }));
    await assertSucceeds(updateDoc(doc(db('shop'), 'orders/o1'), { quoteRm: 180, stage: 'cut' }));
    await assertFails(updateDoc(doc(db('shop'), 'orders/o1'), { stage: 'submitted' }));
    await assertFails(updateDoc(doc(db('shop'), 'orders/o1'), { stage: 'teleported' }));
    await assertFails(updateDoc(doc(db('shop'), 'orders/o1'), { customerUid: 'shop' }));
    await assertFails(updateDoc(doc(db('shop'), 'orders/o1'), { quoteRm: -10 }));
    await assertFails(deleteDoc(doc(db('shop'), 'orders/o1')));
  });
});
