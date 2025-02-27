WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Views,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS Author,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopAcclaimedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.Score,
        rp.Views,
        rp.RankByScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownvoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.Author,
        ap.Score,
        up.UpvoteCount,
        dp.DownvoteCount,
        COALESCE(up.UpvoteCount, 0) - COALESCE(dp.DownvoteCount, 0) AS NetVoteCount
    FROM 
        TopAcclaimedPosts ap
    LEFT JOIN 
        PostVoteCounts up ON ap.PostId = up.PostId
    LEFT JOIN 
        PostVoteCounts dp ON ap.PostId = dp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Author,
    pd.Score,
    pd.UpvoteCount,
    pd.DownvoteCount,
    pd.NetVoteCount,
    CASE 
        WHEN pd.NetVoteCount IS NULL THEN 'No votes yet'
        WHEN pd.NetVoteCount > 0 THEN 'Positively acclaimed'
        WHEN pd.NetVoteCount < 0 THEN 'Negatively acclaimed'
        ELSE 'Neutral'
    END AS VoteStatus,
    (
        SELECT 
            STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM 
            Tags t 
        JOIN 
            string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_name ON t.TagName = tag_name
        WHERE 
            p.Id = pd.PostId
    ) AS TagsList
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, 
    pd.NetVoteCount DESC
LIMIT 100;

-- This query evaluates posts created in the last year, ranks them based on their score by post type,
-- calculates the net votes for these posts, and categorizes them into different acclaim statuses.
-- Additionally, it retrieves associated tags in a string format, tackling complexities
-- such as associations and aggregations, along with handling NULL values and string manipulations.
