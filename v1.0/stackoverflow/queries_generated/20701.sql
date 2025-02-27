WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0 
),
FeaturedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(pts.Name, 'Unknown') AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pts ON p.PostTypeId = pts.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Score >= (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
    GROUP BY 
        p.Id, p.Title, pts.Name
    HAVING 
        COUNT(c.Id) > 5 OR SUM(v.BountyAmount) > 0
),
UserActivityLog AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Title AS PostTitle,
        p.CreationDate AS PostCreationDate,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment AS ActionComment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
)
SELECT 
    ubs.DisplayName,
    ubs.BadgeCount,
    ubs.GoldBadgeCount,
    ubs.SilverBadgeCount,
    ubs.BronzeBadgeCount,
    tq.Title AS TopQuestionTitle,
    tq.CreationDate AS TopQuestionDate,
    fp.Title AS FeaturedPostTitle,
    fp.TotalVotes,
    ul.PostTitle,
    ul.HistoryCreationDate,
    ul.ActionComment,
    ul.PostHistoryTypeId
FROM 
    UserBadgeStats ubs
LEFT JOIN 
    TopQuestions tq ON ubs.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tq.Id)
LEFT JOIN 
    FeaturedPosts fp ON fp.PostId = (SELECT Id FROM FeaturedPosts ORDER BY TotalBounties DESC LIMIT 1)
LEFT JOIN 
    UserActivityLog ul ON ul.UserId = ubs.UserId AND ul.ActivityRank = 1
WHERE 
    (ubs.BadgeCount > 0 OR ubs.GoldBadgeCount > 0) 
ORDER BY 
    ubs.BadgeCount DESC, ubs.DisplayName ASC, fq.Title ASC
LIMIT 100;
