WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(a.Id) AS AnswerCount,
        AVG(v.BountyAmount) AS AvgBounty,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS t
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) -- Bounty Start and Close
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount
),

FilteredRankedPosts AS (
    SELECT 
        *,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId
    WHERE 
        rp.Score > 0 
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName, rp.Tags, rp.AvgBounty, rp.PostRank
)

SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    ViewCount,
    AnswerCount,
    CommentCount,
    BadgeCount,
    COALESCE(AvgBounty, 0) AS AvgBounty,
    Tags,
    CreationDate
FROM 
    FilteredRankedPosts
WHERE 
    PostRank <= 5  -- Top 5 posts per user
ORDER BY 
    Score DESC, 
    ViewCount DESC;
