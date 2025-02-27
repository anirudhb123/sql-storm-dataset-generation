WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVoteCount,
        COALESCE(NULLIF(p.Body, ''), 'No content available') AS BodyContent
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate IS NOT NULL
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.BodyContent,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.Score IS NULL THEN 'No score'
            WHEN rp.Score < 0 THEN 'Negative score'
            ELSE 'Positive score'
        END AS ScoreStatus,
        CASE 
            WHEN rp.PostRank = 1 THEN 'Latest post'
            ELSE 'Older post'
        END AS PostAge
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostTypeId IN (1, 2)  -- Consider only Questions and Answers
    AND 
        rp.UpVoteCount - rp.DownVoteCount > 0  -- Only include posts with a net positive score
)

SELECT 
    fp.Title,
    fp.BodyContent,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.ScoreStatus,
    fp.PostAge,
    u.DisplayName,
    u.Reputation,
    u.Location,
    ARRAY(SELECT DISTINCT tag.TagName FROM Tags tag 
          JOIN LATERAL STRING_TO_ARRAY(fp.BodyContent, ' ') AS words(word) 
          ON tag.TagName ILIKE '%' || word || '%') AS TagsMentioned
FROM 
    FilteredPosts fp
JOIN 
    Users u ON u.Id = fp.OwnerUserId
WHERE 
    u.Reputation BETWEEN 100 AND 1000  -- Filter for users with a specific reputation range
ORDER BY 
    fp.UpVoteCount DESC, 
    fp.CreationDate DESC
LIMIT 50;

-- Notice the use of outer joins for user and voting data, window functions for ranking,
-- correlated subqueries to find tags mentioned in post bodies, and where conditions dealing with NULLs, 
-- a variety of CASE constructs, and distinct counts to enrich the analysis of posts.
