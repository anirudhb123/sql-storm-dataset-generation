
WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
),

RecentActivity AS (
    SELECT 
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5)
    WHERE 
        p.CreationDate > DATEADD(DAY, -30, CAST('2024-10-01 12:34:56' AS DATETIME))
    GROUP BY 
        p.Title, p.CreationDate, u.DisplayName
),

TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(*) AS PostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.CreationDate < DATEADD(YEAR, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
    GROUP BY 
        u.DisplayName, u.Reputation
    ORDER BY 
        u.Reputation DESC
)

SELECT 
    tc.TagName,
    tc.PostCount,
    tc.QuestionCount,
    tc.AnswerCount,
    ra.Title AS RecentPost,
    ra.CreationDate AS RecentPostDate,
    ra.OwnerDisplayName AS RecentPostOwner,
    ra.CommentCount AS RecentCommentCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS TopUserReputation,
    tu.PostsCount AS TopUserPostCount
FROM 
    TagCounts tc
JOIN 
    RecentActivity ra ON CHARINDEX(tc.TagName, ra.Title) > 0 
JOIN 
    TopUsers tu ON ra.OwnerDisplayName = tu.DisplayName
ORDER BY 
    tc.PostCount DESC, ra.CreationDate DESC, tu.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
