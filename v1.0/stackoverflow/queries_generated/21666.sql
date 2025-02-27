WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 5
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        Badges b ON v.UserId = b.UserId
    GROUP BY 
        v.PostId
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN pv.UpVotes > pv.DownVotes THEN 'Positive'
        WHEN pv.UpVotes < pv.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = fp.PostId AND v.UserId = 1) THEN 'User Has Voted'
        ELSE 'User Has Not Voted'
    END AS UserVoteStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostVotes pv ON fp.PostId = pv.PostId
ORDER BY 
    fp.ViewCount DESC, fp.Score DESC
FETCH FIRST 10 ROWS ONLY;

-- Additionally, checking for correlated subqueries in the WHERE clause:
SELECT 
    p.Title,
    p.CreationDate,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
FROM 
    Posts p
WHERE 
    p.Score > (SELECT AVG(Score) FROM Posts)  -- Only select posts with above average score
AND 
    EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2)  -- At least one upvote
ORDER BY 
    CommentCount DESC, p.CreationDate DESC;

-- Utilizing outer joins with NULL logic:
SELECT 
    u.DisplayName,
    COALESCE(UPPER(u.Location), 'Location not provided') AS Location,
    ISNULL(p.Title, 'No Title') AS PostTitle,
    ISNULL(c.Text, 'No Comments') AS CommentText
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    u.Reputation > 1000 AND 
    (p.CreationDate IS NULL OR p.CreationDate >= CURRENT_DATE - INTERVAL '30 days')
ORDER BY 
    u.Reputation DESC;
