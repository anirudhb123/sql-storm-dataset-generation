WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),
TopRankedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Body,
        rp.Score,
        rp.ViewCount,
        rp.AcceptedAnswerId,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3 -- Get top 3 posts per user
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '>')) AS t(TagName) ON t.TagName IS NOT NULL
    GROUP BY 
        p.Id
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    trp.Title,
    trp.Body,
    trp.Score,
    trp.ViewCount,
    COALESCE(PV.UpVotes, 0) AS UpVotes,
    COALESCE(PV.DownVotes, 0) AS DownVotes,
    pts.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    CASE 
        WHEN trp.AcceptedAnswerId IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS HasAcceptedAnswer
FROM 
    TopRankedPosts trp
JOIN 
    Users u ON trp.OwnerUserId = u.Id
JOIN 
    PostTags pts ON trp.Id = pts.PostId
LEFT JOIN 
    PostVoteStats PV ON trp.Id = PV.PostId
WHERE 
    u.Reputation > 100 -- Only include users with reputation greater than 100
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;

WITH RECURSIVE UserWithBadges AS (
    SELECT
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class
    FROM 
        Users u
    INNER JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1 -- Gold badge
    UNION ALL
    SELECT
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class
    FROM 
        Users u
    INNER JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 2 -- Silver badge
)
SELECT 
    uwb.UserId,
    STRING_AGG(uwb.BadgeName, ', ') AS Badges
FROM 
    UserWithBadges uwb
GROUP BY 
    uwb.UserId
HAVING 
    COUNT(uwb.BadgeName) > 1;  -- Only users with more than one badge
