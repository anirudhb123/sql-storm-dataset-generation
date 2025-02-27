WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            Id, 
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName 
         FROM 
            Posts) t ON p.Id = t.Id
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentPostEdits AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title,
    pt.TagCount,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    rpe.LastEditDate
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
JOIN 
    PostTagCounts pt ON u.Id = pt.PostId
LEFT JOIN 
    RecentPostEdits rpe ON pt.PostId = rpe.PostId
WHERE 
    ua.PostCount > 0
ORDER BY 
    ua.PostCount DESC, 
    pt.TagCount DESC;
