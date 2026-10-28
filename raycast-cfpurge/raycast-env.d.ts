/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {
  /** Jeton API Cloudflare - Token API avec permission Zone → Cache Purge. Indépendant du Keychain de l'app CFPurge. */
  "cloudflareToken": string,
  /** Jeton API Hostinger - Token API Hostinger (hPanel → API). Requis pour purger les sites Hostinger. */
  "hostingerToken"?: string
}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `purge-url` command */
  export type PurgeUrl = ExtensionPreferences & {}
  /** Preferences accessible in the `purge-all` command */
  export type PurgeAll = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `purge-url` command */
  export type PurgeUrl = {}
  /** Arguments passed to the `purge-all` command */
  export type PurgeAll = {}
}

