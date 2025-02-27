
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
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
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostCounts
),
LatestPosts AS (
    SELECT 
        p.*,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryWithTags AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1)) AS tag 
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
               SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
               SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS tag 
        ON tag IS NOT NULL 
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    pp.LastEditDate,
    p.Tags,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory,
    pp.Body AS MostRecentPostBody
FROM 
    TopUsers tu
LEFT JOIN 
    LatestPosts pp ON tu.UserId = pp.OwnerUserId AND pp.rn = 1
LEFT JOIN 
    PostHistoryWithTags p ON pp.Id = p.PostId
LEFT JOIN 
    PostVotes pv ON pp.Id = pv.PostId
WHERE 
    tu.PostCount > 0
    AND (p.LastEditDate < '2024-10-01 12:34:56' - INTERVAL 1 YEAR OR p.LastEditDate IS NULL)
ORDER BY 
    tu.PostCount DESC, tu.DisplayName;
