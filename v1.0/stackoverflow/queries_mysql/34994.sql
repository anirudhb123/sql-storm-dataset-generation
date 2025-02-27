
WITH RECURSIVE UserHierarchy AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        Location,
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000
    
    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Location,
        uh.Level + 1
    FROM 
        Users u
    INNER JOIN UserHierarchy uh ON u.Id = uh.Id
    WHERE 
        u.Reputation > 500 AND uh.Level < 5
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes,
        (SELECT COUNT(*) FROM Posts AS p2 WHERE p2.ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    INNER JOIN 
        PostStatistics ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN ( 
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)
SELECT 
    u.DisplayName,
    u.Reputation,
    th.PostsCount,
    th.TotalUpVotes,
    th.TotalDownVotes,
    GROUP_CONCAT(ts.TagName) AS PopularTags,
    @row_number := @row_number + 1 AS UserRank
FROM 
    TopUsers th
JOIN 
    Users u ON th.Id = u.Id
LEFT JOIN 
    TagStats ts ON ts.PostCount > 5
JOIN (SELECT @row_number := 0) r
WHERE 
    u.Location IS NOT NULL
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, th.PostsCount, th.TotalUpVotes, th.TotalDownVotes
ORDER BY 
    UserRank;
