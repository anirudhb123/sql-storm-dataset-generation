
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR 
        AND p.PostTypeId = 1
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT v.UserId) AS AcceptedVoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(rv.Upvotes, 0) AS Upvotes,
    COALESCE(rv.Downvotes, 0) AS Downvotes,
    rv.AcceptedVoteCount AS AcceptedVotes,
    rp.CommentCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        WHEN rp.CommentCount > 5 THEN 'Popular'
        ELSE 'Standard' 
    END AS PostCategory,
    GROUP_CONCAT(DISTINCT ExtractedTags.TagName SEPARATOR ', ') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    ( 
        SELECT 
            unnest(string_split(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
        FROM 
            Posts p 
    ) AS ExtractedTags ON ExtractedTags.TagName IS NOT NULL
WHERE 
    (rp.Score - COALESCE(rv.Downvotes, 0)) > 0
    AND (EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = rp.PostId AND v.UserId IS NULL 
    ) OR rp.CommentCount > 10)
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ViewCount, rv.Upvotes, rv.Downvotes, rv.AcceptedVoteCount, rp.CommentCount, rp.PostRank
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, rp.PostRank DESC;
