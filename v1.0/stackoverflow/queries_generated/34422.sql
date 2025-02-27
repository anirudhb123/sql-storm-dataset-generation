WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(a.Score, 0) AS AcceptedScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        pp.Id,
        pp.Title,
        pp.OwnerUserId,
        pp.AcceptedAnswerId,
        pp.CreationDate,
        pp.LastActivityDate,
        COALESCE(pa.Score, 0) AS AcceptedScore
    FROM 
        Posts pp
    INNER JOIN 
        RecursivePosts rp ON pp.ParentId = rp.Id
    LEFT JOIN 
        Posts pa ON pp.AcceptedAnswerId = pa.Id
),
UserAnalytics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS QuestionsAsked,
        COUNT(v.Id) AS TotalVotes,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RankedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.LastActivityDate DESC) AS ActivityRank,
        ROW_NUMBER() OVER (ORDER BY rp.AcceptedScore DESC) AS PopularityRank
    FROM 
        RecursivePosts rp
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.TotalComments, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS TotalComments 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON p.Id = c.PostId
 )
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionsAsked,
    ua.TotalVotes,
    ua.TotalBadges,
    rp.Title,
    rp.CreationDate,
    rp.ActivityRank,
    rp.PopularityRank,
    pc.CommentCount
FROM 
    UserAnalytics ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId
JOIN 
    PostsWithComments pc ON rp.Id = pc.PostId
WHERE 
    ua.TotalVotes > 10   -- Only consider users with more than 10 votes
    AND rp.LastActivityDate >= NOW() - INTERVAL '1 year'  -- Activity in the last year
ORDER BY 
    ua.TotalBadges DESC,  -- Sort by the most badges first
    rp.PopularityRank;     -- Then by post popularity
