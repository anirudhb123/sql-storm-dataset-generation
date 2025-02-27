WITH TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Question' AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestionCount,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS UserContributedPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        TagName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsPosted,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersPosted
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastModified,
        STRING_AGG(DISTINCT CAST(pt.Name AS VARCHAR), ', ') AS ChangesMade,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseRequests,
        SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS SuggestedEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS Deletions
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId, p.Title
),
BenchmarkResults AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.AnswerCount,
        ts.AcceptedQuestionCount,
        ts.UserContributedPosts,
        tu.DisplayName AS TopUser,
        tu.TotalPosts AS UserPostCount,
        ph.LastModified,
        ph.ChangesMade,
        ph.CloseRequests,
        ph.SuggestedEdits,
        ph.Deletions
    FROM 
        TagStatistics ts
    JOIN 
        TopUsers tu ON ts.UserContributedPosts >= 5
    JOIN 
        PostHistoryDetails ph ON ph.PostId IN (
            SELECT 
                p.Id 
            FROM 
                Posts p 
            WHERE 
                p.Tags LIKE '%' || ts.TagName || '%'
            LIMIT 5
        )
    ORDER BY 
        ts.PostCount DESC, 
        tu.TotalPosts DESC
)
SELECT 
    *
FROM 
    BenchmarkResults
LIMIT 100;
