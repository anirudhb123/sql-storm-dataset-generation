WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS NetVotes,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY UpVotes DESC, TotalPosts DESC) AS Rank
    FROM 
        UserStats
),
PostAudit AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.UserId AS EditorId,
        PH.CreationDate AS EditDate,
        COUNT(*) OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS EditCount
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 year'
    AND 
        P.PostTypeId IN (1, 2) -- Only Questions and Answers
)
SELECT 
    tu.DisplayName,
    tu.NetVotes,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    CASE 
        WHEN pa.EditCount IS NULL THEN 0 
        ELSE pa.EditCount 
    END AS RecentEditingCount
FROM 
    TopUsers tu
LEFT JOIN 
    PostAudit pa ON tu.UserId = pa.EditorId
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.NetVotes DESC, tu.TotalPosts DESC;
