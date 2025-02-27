WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.TotalScore,
        ua.QuestionCount,
        ua.AnswerCount
    FROM 
        UserActivity ua
    WHERE 
        ua.Rank <= 10
),
RecentPostEdits AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS EditedBy,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Title and Body edits
)
SELECT 
    pu.DisplayName AS PopularUser,
    pu.Reputation,
    pu.TotalScore,
    COALESCE(SUM(CASE WHEN pp.EditedBy IS NOT NULL THEN 1 ELSE 0 END), 0) AS EditCount,
    STRING_AGG(DISTINCT rp.Title, ', ') AS EditedPosts,
    (SELECT 
        STRING_AGG(TAG.TagName, ', ') 
     FROM 
        (SELECT unnest(string_to_array(p.Tags, '><')) AS TagName) AS TAG
     WHERE 
        TAG.TagName IS NOT NULL
     ) AS TagList
FROM 
    PopularUsers pu
LEFT JOIN 
    RecentPostEdits pp ON pu.UserId = pp.EditedBy
LEFT JOIN 
    Posts p ON pp.PostId = p.Id
GROUP BY 
    pu.UserId, pu.DisplayName, pu.Reputation, pu.TotalScore
ORDER BY 
    pu.Reputation DESC;
