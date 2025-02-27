
WITH TagCounts AS (
    SELECT 
        TRIM(tag) AS TagName, 
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '> <', numbers.n), '> <', -1) AS tag
        FROM 
            Posts
        INNER JOIN (
          SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '> <', '')) >= numbers.n - 1
        WHERE 
            PostTypeId = 1 
    ) AS tags
    GROUP BY 
        TRIM(tag)
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        @rn := @rn + 1 AS rn
    FROM 
        TagCounts, (SELECT @rn := 0) r
    WHERE 
        PostCount > 5 
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVotes, 
        DownVotes,
        QuestionCount,
        CommentCount,
        @rn2 := @rn2 + 1 AS rn 
    FROM 
        PopularUsers, (SELECT @rn2 := 0) r
    WHERE 
        QuestionCount > 2 
),
PostHistoryInfo AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(DISTINCT ph.Id) AS EditCount,
        GROUP_CONCAT(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    tt.TagName, 
    tt.PostCount, 
    tu.DisplayName AS TopUser, 
    tu.QuestionCount, 
    ph.PostId, 
    ph.Title, 
    ph.LastEdited, 
    ph.EditCount,
    ph.Editors
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tu.QuestionCount > 5 
JOIN 
    PostHistoryInfo ph ON ph.Title LIKE CONCAT('%', tt.TagName, '%') 
WHERE 
    tu.rn <= 10 AND 
    tt.rn <= 10 
ORDER BY 
    tt.PostCount DESC, tu.UpVotes DESC;
