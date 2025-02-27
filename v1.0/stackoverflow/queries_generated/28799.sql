WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.*,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Badges b ON rp.OwnerUserId = b.UserId
    WHERE 
        rp.rn = 1 AND
        rp.ViewCount > 100 AND -- Filter for posts with more than 100 views
        rp.Score > 0 -- Considering only posts with a positive score
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Score, rp.AnswerCount, rp.OwnerDisplayName, rp.Reputation
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.AnswerCount,
    fp.OwnerDisplayName,
    fp.Reputation,
    fp.CommentCount,
    fp.BadgeCount,
    fp.Tags
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 50; -- Limit to top 50 posts based on score and view count
