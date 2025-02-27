WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ARRAY(
            SELECT unnest(string_to_array(trim(both '<>' FROM p.Tags), '><')) 
            ORDER BY COUNT(*) OVER (PARTITION BY unnest(string_to_array(trim(both '<>' FROM p.Tags), '><'))) DESC
            LIMIT 3
        ) AS TopTags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS RankByUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        v.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(rv.VoteCount, 0) AS VoteCount,
        rp.TopTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.RankByUser <= 5 -- Top 5 Posts per User
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerDisplayName,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.VoteCount,
    pm.TopTags,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
FROM 
    PostMetrics pm
LEFT JOIN 
    Badges b ON pm.OwnerDisplayName = b.UserId
GROUP BY 
    pm.PostId, pm.Title, pm.OwnerDisplayName, pm.CreationDate, pm.ViewCount, pm.Score, pm.VoteCount, pm.TopTags
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
LIMIT 10;

This query benchmarks string processing and aggregates post metrics while also considering user badges, ranking posts by users. It utilizes common table expressions (CTEs), string manipulation functions, and aggregation functions to present insightful data about recently generated content in the Stack Overflow schema.
