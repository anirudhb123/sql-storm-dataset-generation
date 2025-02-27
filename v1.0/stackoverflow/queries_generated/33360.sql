WITH RecursivePostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        1 AS LinkLevel
    FROM 
        PostLinks pl
    WHERE 
        pl.LinkTypeId = 3  -- Starting with duplicates
    UNION ALL
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        rp.LinkLevel + 1
    FROM 
        PostLinks pl
    INNER JOIN 
        RecursivePostLinks rp ON pl.PostId = rp.RelatedPostId
    WHERE 
        pl.LinkTypeId = 3
),
UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(cm.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes  -- Count downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments cm ON cm.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Posts from the last year
    GROUP BY 
        p.Id, p.OwnerUserId
),
PostDetails AS (
    SELECT 
        pa.PostId,
        pa.CommentCount,
        pa.UpVotes,
        pa.DownVotes,
        COALESCE(rp.RelatedPostId, 0) AS DuplicatedPostId  -- Null handling for no duplicates
    FROM 
        PostActivity pa
    LEFT JOIN 
        RecursivePostLinks rp ON pa.PostId = rp.PostId
),
FinalSelection AS (
    SELECT 
        pd.PostId,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        u.DisplayName AS OwnerName,
        ur.Reputation AS OwnerReputation,
        ur.ReputationRank
    FROM 
        PostDetails pd
    INNER JOIN 
        Users u ON pd.OwnerUserId = u.Id
    INNER JOIN 
        UserReputationCTE ur ON u.Id = ur.UserId
    WHERE 
        (pd.UpVotes - pd.DownVotes) > 5  -- Filter for posts with a net positive score
)

SELECT 
    fs.PostId,
    fs.CommentCount,
    fs.UpVotes,
    fs.DownVotes,
    fs.OwnerName,
    fs.OwnerReputation,
    CASE 
        WHEN fs.OwnerReputation > 1000 THEN 'Highly Reputable'
        WHEN fs.OwnerReputation BETWEEN 500 AND 1000 THEN 'Moderately Reputable'
        ELSE 'New User'
    END AS ReputationCategory,
    COALESCE(t.TagName, 'No Tag') AS MostRelevantTag
FROM 
    FinalSelection fs
LEFT JOIN 
    (SELECT 
        p.Id, 
        STRING_AGG(t.TagName, ', ') AS TagName
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    GROUP BY 
        p.Id
    ) t ON t.Id = fs.PostId
ORDER BY 
    fs.ReputationRank, fs.UpVotes DESC;

