
WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = p.OwnerUserId) AS AvgOwnerPostScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        @row_num := @row_num + 1 AS UserRank
    FROM 
        Users u, (SELECT @row_num := 0) r
    ORDER BY 
        u.Reputation DESC
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    COALESCE(ur.UserRank, 0) AS OwnerRank,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.AvgOwnerPostScore,
    CASE 
        WHEN pa.UpVoteCount - pa.DownVoteCount > 0 THEN 'Positive'
        WHEN pa.UpVoteCount - pa.DownVoteCount < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PostAnalytics pa
LEFT JOIN 
    UserReputation ur ON pa.OwnerUserId = ur.UserId
ORDER BY 
    pa.CreationDate DESC
LIMIT 100;
