WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalUpVotes,
        TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
),
PostHistoryCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS TotalEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TitleAndBodyEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.TotalPosts,
        tu.TotalQuestions,
        tu.TotalAnswers,
        tu.TotalScore,
        tu.TotalUpVotes,
        tu.TotalDownVotes,
        COALESCE(phc.TotalEdits, 0) AS TotalEdits,
        COALESCE(phc.TitleAndBodyEdits, 0) AS TitleAndBodyEdits
    FROM 
        TopUsers tu
    LEFT JOIN 
        PostHistoryCounts phc ON tu.UserId = phc.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalUpVotes,
    TotalDownVotes,
    TotalEdits,
    TitleAndBodyEdits
FROM 
    CombinedStats
WHERE 
    Rank <= 10
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
