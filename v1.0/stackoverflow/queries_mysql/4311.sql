
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
RankedUsers AS (
    SELECT 
        us.*,
        @rank := IF(@prev_reputation = us.Reputation AND @prev_postcount = us.PostCount, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := us.Reputation,
        @prev_postcount := us.PostCount
    FROM 
        UserStats us, (SELECT @rank := 0, @prev_reputation := NULL, @prev_postcount := NULL) r
    ORDER BY 
        us.Reputation DESC, us.PostCount DESC
),
TopPostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
    HAVING 
        COUNT(p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS ClosedPostCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
)
SELECT 
    ru.UserId, 
    ru.DisplayName, 
    ru.PostCount, 
    ru.AnswerCount, 
    ru.TotalViews, 
    ru.ReputationRank,
    COALESCE(top.TotalPosts, 0) AS TotalPostsByUser,
    COALESCE(cp.ClosedPostCount, 0) AS ClosedPostsByUser
FROM 
    RankedUsers ru
LEFT JOIN 
    TopPostCounts top ON ru.UserId = top.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON ru.UserId = cp.UserId
WHERE 
    ru.ReputationRank <= 10
ORDER BY 
    ru.ReputationRank;
