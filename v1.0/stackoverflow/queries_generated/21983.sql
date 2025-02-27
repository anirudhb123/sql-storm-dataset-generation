WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

QuestionPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(vh.LastVoteDate, '1900-01-01') AS LastVoteDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY vh.LastVoteDate DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            MAX(CreationDate) AS LastVoteDate
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vh ON p.Id = vh.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, vh.LastVoteDate
),

AggregatedResults AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.UpVotesCount,
        u.DownVotesCount,
        q.PostId,
        q.Title,
        q.CreationDate,
        q.ViewCount,
        q.LastVoteDate,
        q.CommentCount,
        CASE 
            WHEN q.VoteRank = 1 THEN 'Most Recently Voted'
            ELSE 'Not Most Recently Voted'
        END AS VoteStatus
    FROM 
        UserVoteStats u
    INNER JOIN 
        QuestionPostDetails q ON u.UserId = p.OwnerUserId
    WHERE 
        u.UpVotesCount > u.DownVotesCount
        OR (u.UpVotesCount = u.DownVotesCount AND u.PostsCount > 5)
)

SELECT 
    ar.UserId,
    ar.DisplayName,
    ar.Title AS QuestionTitle,
    ar.CreationDate AS QuestionDate,
    ar.ViewCount AS QuestionViewCount,
    ar.LastVoteDate,
    ar.CommentCount AS QuestionCommentCount,
    ar.UpVotesCount,
    ar.DownVotesCount,
    (ar.UpVotesCount - ar.DownVotesCount) AS NetVotes,
    CASE 
        WHEN ar.LastVoteDate IS NOT NULL AND ar.LastVoteDate < NOW() - INTERVAL '7 days' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    AggregatedResults ar
WHERE 
    ar.VoteStatus = 'Most Recently Voted'
ORDER BY 
    ar.NetVotes DESC, ar.QuestionViewCount DESC
LIMIT 100;
