WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate BETWEEN '2023-01-01' AND CURRENT_TIMESTAMP
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(rb.BadgeCount, 0) AS UserBadgeCount,
        rb.BadgeNames
    FROM 
        Posts p
    LEFT JOIN 
        PostComments pc ON p.Id = pc.PostId
    LEFT JOIN 
        UserBadges rb ON p.OwnerUserId = rb.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.CommentCount,
    pd.UserBadgeCount,
    pd.BadgeNames,
    CASE 
        WHEN pd.Score > 100 THEN 'Highly Engaged'
        WHEN pd.Score > 50 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    COALESCE(
        (SELECT
            STRING_AGG(DISTINCT t.TagName, ', ') 
         FROM 
            Tags t 
         WHERE 
            t.Id IN (SELECT unnest(string_to_array(pd.Tags, ','))::int)
        ), 'No Tags') AS AssociatedTags
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 10
ORDER BY 
    pd.Score DESC,
    pd.Title ASC
LIMIT 100;

-- Additional obscure query testing the clone behaviors of a nested query without aliasing
WITH CloneBehavior AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.Comment,
        ph.CreationDate,
        MIN(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS FirstEditDate,
        COUNT(*) OVER (PARTITION BY ph.UserId) AS UserEditCount,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS RowNum
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
)
SELECT 
    cb.PostId,
    COUNT(DISTINCT cb.UserId) AS UniqueEditors,
    MAX(cb.UserEditCount) AS MaxEditsBySingleUser,
    MIN(cb.FirstEditDate) AS EarliestEditDate,
    COUNT(*) FILTER (WHERE cb.RowNum = 1) AS FirstEditTotal  
FROM 
    CloneBehavior cb
GROUP BY 
    cb.PostId
HAVING 
    COUNT(DISTINCT cb.UserId) > 1
ORDER BY 
    UniqueEditors DESC;
