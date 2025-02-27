WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        p.OwnerUserId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'), '::int')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CommentCount, p.CreationDate, p.OwnerUserId
),
TopPostStatistics AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ps.CreationDate,
        ps.OwnerUserId, 
        us.DisplayName AS OwnerDisplayName,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.TotalVotes,
        ps.Tags
    FROM 
        PostStatistics ps
    JOIN 
        UserVotes us ON ps.OwnerUserId = us.UserId
    ORDER BY 
        ps.ViewCount DESC
    LIMIT 10
)
SELECT 
    tps.PostId,
    tps.Title,
    tps.ViewCount,
    tps.AnswerCount,
    tps.CommentCount,
    tps.CreationDate,
    tps.OwnerDisplayName,
    tps.TotalUpVotes,
    tps.TotalDownVotes,
    tps.TotalVotes,
    tps.Tags,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = tps.PostId) AS TotalPostHistoryEntries
FROM 
    TopPostStatistics tps;
