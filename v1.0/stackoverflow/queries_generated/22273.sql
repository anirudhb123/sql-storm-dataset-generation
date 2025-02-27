WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(v.VoteTypeId = 2) DESC) AS VoteRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistoryAnalytics AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS HasBeenEdited,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY 
        ph.UserId, ph.PostId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionsCount,
        AnswersCount,
        AcceptedAnswersCount,
        TotalBountyAmount,
        TotalUpVotes,
        TotalDownVotes,
        (TotalUpVotes - TotalDownVotes) AS NetScore,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
)
SELECT 
    u.DisplayName,
    ua.UserRank,
    ua.PostCount,
    ua.QuestionsCount,
    ua.AnswersCount,
    ua.AcceptedAnswersCount,
    ua.TotalBountyAmount,
    ua.NetScore,
    ph.EditCount,
    ph.HasBeenEdited,
    ph.CloseReasons
FROM 
    TopUsers ua
LEFT JOIN 
    PostHistoryAnalytics ph ON ua.UserId = ph.UserId
WHERE 
    ua.UserRank <= 10
ORDER BY 
    ua.UserRank;

