WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag ON true
    JOIN 
        Tags t ON tag = t.TagName
    GROUP BY 
        p.Id
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ARRAY_AGG(DISTINCT p.Title) AS UserPosts,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.VoteCount) AS TotalVotes,
        SUM(CASE WHEN rp.AcceptedAnswerId <> 0 THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COUNT(rp.PostId) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.UserPostRank -- Join on users with ranked posts
    GROUP BY 
        u.Id, u.Reputation
),
FinalStats AS (
    SELECT 
        ua.UserId,
        ua.Reputation,
        ua.UserPosts,
        ua.TotalComments,
        ua.TotalVotes,
        ua.AcceptedAnswers,
        ua.PostCount,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS UserRank
    FROM 
        UserAggregates ua
)
SELECT 
    f.UserId,
    f.Reputation,
    f.UserPosts,
    f.TotalComments,
    f.TotalVotes,
    f.AcceptedAnswers,
    f.PostCount,
    f.UserRank
FROM 
    FinalStats f
WHERE 
    f.UserRank <= 10
ORDER BY 
    f.UserRank;
