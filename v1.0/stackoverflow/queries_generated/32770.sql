WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
RelevantTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' -- Example for matching tags
    GROUP BY 
        t.Id, t.TagName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
ImportantBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS ImportantBadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold Badges
    GROUP BY 
        b.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rt.TagName,
    cp.CloseReason,
    ib.ImportantBadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RelevantTags rt ON rt.PostCount > 10 -- Tags associated with significant posts
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
LEFT JOIN 
    ImportantBadges ib ON ib.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = rp.OwnerDisplayName)
WHERE 
    rp.UserPostRank = 1 -- Most recent post per user
    AND (cp.CloseReason IS NULL OR cp.CloseRank <= 3) -- Include posts that are either open or closed recently
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
