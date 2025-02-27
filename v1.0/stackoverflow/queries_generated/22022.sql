WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
QuestionTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS Tag,
        Id AS PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
ClosedPostActivities AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN ct.Name 
            ELSE 'Other' 
        END AS ActivityType
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE 
        ph.CreationDate >= DATEADD(month, -6, GETDATE())
)

SELECT 
    u.DisplayName,
    u.Reputation,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    COALESCE(MAX(bp.Title), 'No Posts') AS BestPostTitle,
    STRING_AGG(DISTINCT qt.Tag, ', ') AS AssociatedTags,
    cp.ActivityType AS CloseActivityType,
    COUNT(DISTINCT cp.PostId) AS ClosedPostCount
FROM 
    Users u
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts bp ON u.Id = bp.PostId
LEFT JOIN 
    QuestionTags qt ON bp.PostId = qt.PostId
LEFT JOIN 
    ClosedPostActivities cp ON u.Id = cp.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, cp.ActivityType
HAVING 
    COUNT(DISTINCT cp.PostId) > 1 OR us.TotalPosts > 10
ORDER BY 
    u.Reputation DESC, us.TotalPosts DESC
OPTION (MAXRECURSION 0);
