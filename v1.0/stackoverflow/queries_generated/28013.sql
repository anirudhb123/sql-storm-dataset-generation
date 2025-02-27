WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        CONCAT(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), ' (Tag Count:', LENGTH(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2)) - LENGTH(REPLACE(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><', '')) + 1, ' )') AS FormattedTags,
        U.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        C.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) C ON p.Id = C.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 month'  -- Posts from the last month
)

SELECT 
    RankedPosts.PostId, 
    RankedPosts.Title, 
    RankedPosts.FormattedTags,
    RankedPosts.OwnerDisplayName,
    COUNT(PH.Id) AS EditCount,
    MAX(B.Date) AS LastBadgeDate,
    COUNT(DISTINCT V.UserId) AS VoterCount
FROM 
    RankedPosts
LEFT JOIN 
    PostHistory PH ON RankedPosts.PostId = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)  -- Counts specific edits
LEFT JOIN 
    Badges B ON B.UserId = RankedPosts.OwnerDisplayName  -- User's badges
LEFT JOIN 
    Votes V ON V.PostId = RankedPosts.PostId  -- Count of unique voters
WHERE 
    RankedPosts.Rank <= 10  -- Top 10 questions per post type
GROUP BY 
    RankedPosts.PostId, 
    RankedPosts.Title, 
    RankedPosts.FormattedTags, 
    RankedPosts.OwnerDisplayName
ORDER BY 
    RankedPosts.Score DESC, 
    LastBadgeDate DESC;
