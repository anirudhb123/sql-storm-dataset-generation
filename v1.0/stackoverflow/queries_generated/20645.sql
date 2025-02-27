WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        U.Reputation,
        U.DisplayName,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        CASE 
            WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN 'Old' 
            ELSE 'New' 
        END AS PostAge,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    JOIN Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId IN (1, 2) AND -- Questions and Answers
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
AggregatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostMetrics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.PostTypeId,
        RP.Score,
        RP.ViewCount,
        RP.CommentCount,
        RP.Reputation,
        RP.DisplayName,
        RP.PostAge,
        COALESCE(AV.TotalUpVotes, 0) AS TotalUpVotes,
        COALESCE(AV.TotalDownVotes, 0) AS TotalDownVotes,
        CASE 
            WHEN RP.Upvotes > RP.Downvotes THEN 'Positive'
            WHEN RP.Upvotes < RP.Downvotes THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment
    FROM 
        RankedPosts RP
    LEFT JOIN 
        AggregatedVotes AV ON RP.PostId = AV.PostId
)
SELECT 
    PM.*,
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = PM.PostId AND PH.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = PM.OwnerUserId) AS OwnerBadgesCount
FROM 
    PostMetrics PM
WHERE 
    PM.Rank <= 5 AND 
    PM.PostAge = 'New'
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC;

-- Optional: Test for outer joins and include possible nulls
SELECT 
    PM.PostId,
    PM.Title,
    COALESCE(B.Name, 'No Badge') AS BadgeName,
    PM.TotalUpVotes,
    PM.TotalDownVotes,
    COALESCE((SELECT COUNT(*) FROM PostLinks PL WHERE PL.PostId = PM.PostId), 0) AS RelatedPostsCount
FROM 
    PostMetrics PM
LEFT JOIN 
    Users U ON PM.OwnerUserId = U.Id
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    PM.TotalUpVotes > PM.TotalDownVotes
ORDER BY 
    PM.TotalUpVotes DESC, PM.TotalDownVotes ASC;

-- Edge case for Null logic
SELECT 
    PM.PostId,
    PM.Title,
    CASE 
        WHEN PM.CommentCount IS NULL THEN 'No Comments Yet'
        ELSE CONCAT(PM.CommentCount, ' Comments')
    END AS Comments_Display
FROM 
    PostMetrics PM
WHERE 
    PM.TotalUpVotes IS NOT NULL OR PM.TotalDownVotes IS NOT NULL;
