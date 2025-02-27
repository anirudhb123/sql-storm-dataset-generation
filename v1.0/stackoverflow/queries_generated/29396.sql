WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Filtering for Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswersCount,
        MIN(p.CreationDate) AS FirstPostDate,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT 
        UserId,
        COUNT(*) AS RecentActionsCount,
        COUNT(CASE WHEN PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory
    WHERE 
        CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        UserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.QuestionsCount,
    up.AnswersCount,
    ra.RecentActionsCount,
    ra.CloseReopenCount,
    STRING_AGG(DISTINCT rp.Tags, '; ') AS TagsUsed,
    MAX(rp.ViewCount) AS MaxViewCount,
    MAX(rp.Score) AS MaxScore,
    COUNT(DISTINCT rp.PostId) AS ActivePostsCount
FROM 
    UserStats up
LEFT JOIN 
    RecentActivity ra ON up.UserId = ra.UserId
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation, ra.RecentActionsCount, ra.CloseReopenCount
ORDER BY 
    up.Reputation DESC, Counts.ActivePostsCount DESC;
