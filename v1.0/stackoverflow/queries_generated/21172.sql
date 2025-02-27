WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.Score >= (SELECT AVG(Score) FROM Posts)  -- Filter on posts above average score
      AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Recent posts
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id  -- Cast comment to int for close reason
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Only relevant close actions
    GROUP BY 
        ph.PostId
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON true 
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),
TopPostsWithReasons AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerReputation,
        COALESCE(cpr.CloseReasons, ARRAY[]::varchar[]) AS CloseReasons,
        pt.TagCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostReasons cpr ON rp.PostId = cpr.PostId
    JOIN 
        PostTagCounts pt ON rp.PostId = pt.PostId
    WHERE 
        rp.Rank = 1  -- Only top posts for each user
)
SELECT 
    TPW.PostId,
    TPW.Title,
    TPW.Score,
    TPW.CreationDate,
    TPW.OwnerReputation,
    TPW.CloseReasons,
    TPW.TagCount,
    CASE 
        WHEN TPW.OwnerReputation > 1000 THEN 'Expert'
        ELSE 'Novice'
    END AS UserLevel,
    CONCAT_WS(';', NULLIF(TPW.CloseReasons[1], ''), NULLIF(TPW.CloseReasons[2], '')) AS CloseReasonSnippet,
    CASE 
        WHEN TPW.Score IS NULL THEN 'No Score'
        ELSE TPW.Score::text
    END AS ScoreText
FROM 
    TopPostsWithReasons TPW
WHERE 
    TPW.TagCount > 3  -- More than three tags
ORDER BY 
    TPW.Score DESC, 
    TPW.CreationDate DESC
LIMIT 100;
