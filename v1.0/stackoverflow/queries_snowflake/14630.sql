
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        u.Reputation AS UserReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2020-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.Reputation
)

SELECT 
    AVG(DATEDIFF(MINUTE, PostCreationDate, CURRENT_TIMESTAMP())) AS AvgResponseTimeInMinutes,
    SUM(CommentCount) AS TotalComments,
    SUM(VoteCount) AS TotalVotes
FROM 
    PostDetails;
