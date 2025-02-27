WITH PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, '<deleted>') AS OwnerDisplayName,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT bh.UserId) FILTER (WHERE bh.PostHistoryTypeId IN (10, 11)) AS ClosureCount
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Posts a ON p.Id = a.ParentId -- Answer linked by ParentId
        LEFT JOIN PostHistory bh ON p.Id = bh.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),

TagStatistics AS (
    SELECT
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM
        PostDetails
    GROUP BY TagName
),

TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionsCount
    FROM 
        Users u
        JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 5
)

SELECT
    pd.PostId,
    pd.Title,
    pd.Tags,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.AnswerCount,
    pd.ClosureCount,
    ts.TagName,
    tu.DisplayName AS TopUserName,
    tu.TotalViews,
    tu.TotalScore,
    tu.QuestionsCount
FROM 
    PostDetails pd
LEFT JOIN 
    TagStatistics ts ON pd.Tags LIKE CONCAT('%', ts.TagName, '%')
LEFT JOIN 
    TopUsers tu ON pd.OwnerDisplayName = tu.DisplayName
ORDER BY 
    pd.CreationDate DESC, pd.Score DESC;
