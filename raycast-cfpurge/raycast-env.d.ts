/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `purge-url` command */
  export type PurgeUrl = ExtensionPreferences & {
  /** Jeton API Cloudflare - Token API avec permission Zone → Cache Purge. Indépendant du Keychain de l'app CFPurge. */
  "cloudflareToken": string
}
  /** Preferences accessible in the `purge-all` command */
  export type PurgeAll = ExtensionPreferences & {
  /** Jeton API Cloudflare - Token API Cloudflare (sites Cloudflare). */
  "cloudflareToken": string,
  /** Jeton API Hostinger - Token API Hostinger (hPanel → API). Requis pour les sites Hostinger. */
  "hostingerToken"?: string
}
}

declare namespace Arguments {
  /** Arguments passed to the `purge-url` command */
  export type PurgeUrl = {}
  /** Arguments passed to the `purge-all` command */
  export type PurgeAll = {}
}

