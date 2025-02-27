WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.Id = pt.Id
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10
),
ActivitySummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(ph.PostId, 0)) AS PostHistoryCount,
        SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END) AS VotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    ub.BadgeCount,
    pt.TagName,
    asummary.PostsCreated,
    asummary.PostHistoryCount,
    asummary.VotesReceived
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PopularTags pt ON rp.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE CONCAT('%', pt.TagName, '%'))
LEFT JOIN 
    ActivitySummary asummary ON rp.OwnerUserId = asummary.UserId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
