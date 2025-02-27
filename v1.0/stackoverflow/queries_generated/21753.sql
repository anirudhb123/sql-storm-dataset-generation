WITH RecursivePosts AS (
    -- Recursive CTE to find all answers for all questions along with their associated votes
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        p.CreationDate,
        p.Body,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        0 AS AnswerLevel
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes GROUP BY PostId) vs ON p.Id = vs.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        p.CreationDate,
        p.Body,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        rp.AnswerLevel + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId  -- Finding answers to those questions
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes GROUP BY PostId) vs ON p.Id = vs.PostId
    WHERE 
        p.PostTypeId = 2  -- Only answers
),
AggregatedPosts AS (
    -- Aggregating post results and calculating total score, view count and dynamic reputation ranking
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.UpVotes) AS TotalUpVotes,
        SUM(rp.DownVotes) AS TotalDownVotes,
        SUM(CASE WHEN rp.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(rp.ViewCount) AS TotalViews,
        DATE_TRUNC('month', rp.CreationDate) AS PostMonth
    FROM 
        RecursivePosts rp
    GROUP BY 
        rp.OwnerUserId, DATE_TRUNC('month', rp.CreationDate)
),
FinalOutput AS (
    -- Final output with additional join to rank users based on their reputation
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ap.TotalPosts,
        ap.TotalUpVotes,
        ap.TotalDownVotes,
        ap.AcceptedAnswers,
        ap.TotalViews,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COALESCE(tg.TotalTags, 0) AS TotalTags, -- Joining with Tags for obscure counting
        STRING_AGG(DISTINCT tg.TagName, ', ' ORDER BY tg.TagName) AS Tags
    FROM 
        Users u
    LEFT JOIN 
        AggregatedPosts ap ON u.Id = ap.OwnerUserId
    LEFT JOIN 
        (SELECT 
             t.Id AS TagId,
             t.TagName,
             COUNT(pt.Id) AS TotalTags 
         FROM 
             Tags t
         JOIN 
             Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'   -- Using LIKE with wildcards
         GROUP BY 
             t.Id, t.TagName) tg ON true  -- CROSS JOIN to keep all users and tags 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, ap.TotalPosts, ap.TotalUpVotes, 
        ap.TotalDownVotes, ap.AcceptedAnswers, ap.TotalViews, tg.TotalTags
)
SELECT 
    fo.UserId,
    fo.DisplayName,
    fo.Reputation,
    fo.TotalPosts,
    fo.TotalUpVotes,
    fo.TotalDownVotes,
    fo.AcceptedAnswers,
    fo.TotalViews,
    fo.ReputationRank,
    COALESCE(fo.Tags, 'No Tags') AS DisplayedTags -- Handling NULL logic for tags
FROM 
    FinalOutput fo
WHERE 
    fo.Reputation >= 100  -- Focusing on users with a minimum reputation
ORDER BY 
    fo.ReputationRank
LIMIT 50;  -- Limiting to top 50 users for performance benchmarking
