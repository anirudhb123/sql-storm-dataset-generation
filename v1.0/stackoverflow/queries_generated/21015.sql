WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><') AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
), PostScore AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score + rp.UpVotes - rp.DownVotes AS TotalScore,
        pr.ReputationRank,
        pt.Tags
    FROM 
        RecentPosts rp
    JOIN 
        UserReputation ur ON ur.UserId = rp.OwnerUserId
    JOIN 
        PostTags pt ON pt.PostId = rp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ReputationRank,
    ps.TotalScore,
    CASE
        WHEN ps.TotalScore > 1 THEN 'High'
        WHEN ps.TotalScore BETWEEN -1 AND 1 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory,
    COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount
FROM 
    PostScore ps
LEFT JOIN 
    Comments c ON c.PostId = ps.PostId
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.ReputationRank, ps.TotalScore
HAVING 
    COUNT(c.PostId) IS NOT NULL
ORDER BY 
    ps.ReputationRank ASC, ps.TotalScore DESC
LIMIT 100;

-- Version with outer join and NULL propagation checking
SELECT
    p.Id,
    p.Title,
    COALESCE(c.CommentCount, 0) AS Comments,
    pt.TagCount,
    CASE
        WHEN p.Score IS NULL THEN 'Unknown Score'
        WHEN p.Score < 0 THEN 'Negative'
        ELSE 'Positive'
    END AS ScoreEvaluation
FROM
    Posts p
LEFT JOIN
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN
    (SELECT PostId, COUNT(*) AS TagCount FROM Tags t JOIN PostTags pt ON t.Id = pt.WikiPostId GROUP BY pt.PostId) pt ON p.Id = pt.PostId
WHERE
    p.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY
    CASE 
        WHEN Comments IS NULL THEN 1 
        WHEN Comments BETWEEN 1 AND 3 THEN 2 
        ELSE 0 
    END,
    p.CreationDate DESC
LIMIT 50;
