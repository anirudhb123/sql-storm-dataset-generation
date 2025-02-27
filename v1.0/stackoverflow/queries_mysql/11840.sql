
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
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
        PostCount, 
        UpVotes, 
        DownVotes, 
        CommentCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        UserActivity, (SELECT @rownum := 0) AS r
    ORDER BY 
        PostCount DESC
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount, 
    UpVotes, 
    DownVotes, 
    CommentCount
FROM 
    TopUsers
WHERE 
    Rank <= 10;
