WITH RankedTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
), UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), PostStatistics AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount, 
        COALESCE(ut.UserId, 0) AS TopUserId,
        COALESCE(ut.DisplayName, 'No User') AS TopUserDisplayName,
        COALESCE(ut.UpVotesCount, 0) AS TopUserUpVotes,
        COALESCE(ut.DownVotesCount, 0) AS TopUserDownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            p.Id, 
            u.Id AS UserId, 
            u.DisplayName, 
            COUNT(v.Id) AS VoteCount
        FROM 
            Posts p
        JOIN 
            Votes v ON p.Id = v.PostId
        JOIN 
            Users u ON v.UserId = u.Id
        GROUP BY 
            p.Id, u.Id
        ORDER BY 
            VoteCount DESC
    ) ut ON p.OwnerUserId = ut.UserId
)
SELECT 
    ps.PostId, 
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    rt.TagName,
    ur.DisplayName AS UserWithHighestReputation,
    ur.AverageReputation
FROM 
    PostStatistics ps
JOIN 
    RankedTags rt ON rt.PostCount > 5
JOIN 
    UserReputation ur ON ur.UserId = ps.TopUserId 
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC
LIMIT 100;
