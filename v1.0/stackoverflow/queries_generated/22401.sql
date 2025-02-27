WITH UserPostStats AS (
    -- Aggregate user stats for posts and their scores, including total votes
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS DownVotes,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistoryAnalysis AS (
    -- Track the number of edits and status changes for active posts
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        MIN(ph.CreationDate) AS FirstEdit,
        MAX(ph.CreationDate) AS LastEdit,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
TopUsers AS (
    -- Determine top users with the most posts and varying statuses
    SELECT 
        u.DisplayName,
        ups.TotalPosts,
        ups.UpVotes,
        ups.DownVotes,
        ups.TotalScore,
        pah.PostStatus
    FROM 
        UserPostStats ups
    JOIN 
        Users u ON ups.UserId = u.Id
    JOIN 
        PostHistoryAnalysis pah ON ups.UserId IN (
            SELECT 
                p.OwnerUserId 
            FROM 
                Posts p 
            WHERE 
                p.OwnerUserId IS NOT NULL
        )
    WHERE 
        ups.TotalPosts > 0
    ORDER BY 
        ups.TotalScore DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.UpVotes,
    tu.DownVotes,
    tu.TotalScore,
    tu.PostStatus,
    COALESCE(NULLIF(tu.UpVotes - tu.DownVotes, 0), 'No votes') AS VoteBalance,
    CASE 
        WHEN tu.TotalScore > 100 THEN 'High Contributor'
        WHEN tu.TotalScore BETWEEN 50 AND 100 THEN 'Medium Contributor'
        ELSE 'Low Contributor'
    END AS ContributionLevel
FROM 
    TopUsers tu
LEFT JOIN 
    Users u ON tu.DisplayName = u.DisplayName
WHERE 
    u.CreationDate < NOW() - INTERVAL '1 year'
ORDER BY 
    tu.TotalPosts DESC, tu.TotalScore DESC;
