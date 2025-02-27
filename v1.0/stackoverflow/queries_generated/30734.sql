WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start from Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  -- Questions only
    GROUP BY 
        u.Id, u.Reputation
),
VoteSummary AS (
    SELECT 
        p.OwnerUserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.TotalViews,
    COALESCE(vs.UpVotesCount, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotesCount, 0) AS TotalDownVotes,
    rp.ViewCount AS QuestionViewCount,
    rp.CreationDate,
    STRING_AGG(DISTINCT tg.TagName, ', ') AS TagsListed
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    VoteSummary vs ON u.Id = vs.OwnerUserId
LEFT JOIN 
    RecursivePosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><')) AS tg(TagName) 
WHERE 
    us.Reputation > 1000  -- Filter for high-reputation users
GROUP BY 
    u.DisplayName, us.Reputation, us.QuestionCount, us.TotalViews, rp.ViewCount, rp.CreationDate
ORDER BY 
    us.Reputation DESC,
    us.QuestionCount DESC;
