WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalQuestions,
        us.TotalScore,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.TotalBadges,
        COALESCE(cp.LastClosedDate, 'No Closures') AS LastClosedPost
    FROM 
        UserStats us
    LEFT JOIN 
        ClosedPosts cp ON us.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = cp.PostId)
    ORDER BY 
        us.TotalScore DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.TotalScore,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.TotalBadges,
    COALESCE(t.PostId, 'No Questions') AS LatestQuestionId,
    COALESCE(t.Title, 'No Questions') AS LatestQuestionTitle,
    COALESCE(t.CreationDate, 'No Questions') AS LatestQuestionDate
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts t ON tu.UserId = t.OwnerUserId AND t.rn = 1
ORDER BY 
    tu.TotalScore DESC;
