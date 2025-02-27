WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        array_length(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(AVG(vote.VoteTypeId), 0) AS AverageVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.ViewCount DESC, ps.Score DESC, ps.TagCount DESC) AS Rank
    FROM 
        PostStats ps
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.TagCount,
        p.CommentCount,
        p.AverageVoteType
    FROM 
        RankedPosts p
    WHERE 
        p.Rank <= 10
)

SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    p.TagCount,
    p.CommentCount,
    CASE 
        WHEN p.AverageVoteType IN (2, 3) THEN 'Controversial'
        WHEN p.AverageVoteType = 1 THEN 'Accepted'
        ELSE 'N/A'
    END AS VoteCategory,
    (SELECT STRING_AGG(DISTINCT ut.DisplayName, ', ') 
     FROM Users ut 
     JOIN Posts up ON ut.Id = up.OwnerUserId 
     WHERE up.Id = p.Id) AS TopContributors
FROM 
    TopPosts p
ORDER BY 
    p.ViewCount DESC;
