WITH Benchmark AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        u.Reputation AS UserReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        DATEDIFF(SECOND, p.CreationDate, COALESCE(p.LastActivityDate, CURRENT_TIMESTAMP)) AS PostAgeSeconds
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.Reputation
)
SELECT 
    AVG(UserReputation) AS AvgUserReputation,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(VoteCount) AS AvgVoteCount,
    AVG(PostAgeSeconds) AS AvgPostAgeSeconds
FROM 
    Benchmark;
