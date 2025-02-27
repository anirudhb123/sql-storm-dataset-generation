WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -2, GETDATE())
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges, 
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges, 
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(distinct p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseComment,
        ph.CreationDate AS CloseDate,
        CONCAT(DATEPART(YEAR, ph.CreationDate), '-', DATEPART(MONTH, ph.CreationDate)) AS CloseMonthYear
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Close Post
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        us.UserId,
        us.Reputation,
        pd.CloseComment,
        pd.CloseDate,
        pd.CloseMonthYear
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserStats us ON us.UserId = rp.AcceptedAnswerId
    LEFT JOIN 
        PostHistoryDetails pd ON pd.PostId = rp.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Reputation,
    CASE 
        WHEN fp.CloseComment IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(fp.CloseMonthYear, 'Not Closed') AS ClosedMonthYear,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t
     JOIN Posts p ON t.ExcerptPostId = p.Id 
     WHERE p.Id = fp.PostId) AS AssociatedTags
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC;

SELECT 
    COUNT(DISTINCT UserId) AS UniqueUserCount 
FROM 
    Users 
WHERE 
    Reputation IS NOT NULL
HAVING 
    COUNT(UserId) > 5;

WITH TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON (p.Tags LIKE '%' + t.TagName + '%')
    GROUP BY 
        t.TagName
)
SELECT 
    TagName, 
    UsageCount
FROM 
    TagUsage
WHERE 
    UsageCount > CLAUSE(SELECT AVG(UsageCount) FROM TagUsage);
