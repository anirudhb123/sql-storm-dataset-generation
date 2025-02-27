
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_num := IF(@prev_value = p.PostTypeId, @row_num + 1, 1) AS Rank,
        @prev_value := p.PostTypeId,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM
        Posts p,
        (SELECT @row_num := 0, @prev_value := NULL) AS vars
    WHERE
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.*,
        pcl.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostCloseReasons pcl ON rp.PostId = pcl.PostId
    WHERE 
        rp.Rank <= 5
),
PostSummary AS (
    SELECT
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COALESCE(tp.CloseReasons, 'No close reasons') AS CloseReasons,
        CASE 
            WHEN tp.CommentCount > 10 THEN 'High Engagement'
            WHEN tp.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel,
        COALESCE(tp.UpVoteCount, 0) AS EffectiveUpVoteCount,
        CONCAT('Post: ', tp.Title, ' - Engagement Level: ', 
               CASE 
                   WHEN tp.CommentCount > 10 THEN 'High Engage' 
                   WHEN tp.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engage' 
                   ELSE 'Low Engage' 
               END) AS EngagementDescription
    FROM 
        TopPosts tp
),
FinalOutput AS (
    SELECT 
        *,
        CASE 
            WHEN CHAR_LENGTH(CloseReasons) > 0 THEN 'Has Close Reasons'
            ELSE 'Is Not Closed'
        END AS PostStatus,
        @final_row_num := @final_row_num + 1 AS FinalRank
    FROM 
        PostSummary,
        (SELECT @final_row_num := 0) AS final_vars
)

SELECT 
    Title,
    CreationDate,
    Score,
    ViewCount,
    CloseReasons,
    EngagementLevel,
    EffectiveUpVoteCount,
    EngagementDescription,
    PostStatus,
    FinalRank
FROM 
    FinalOutput
WHERE 
    PostStatus = 'Is Not Closed'
ORDER BY 
    FinalRank, Score DESC;
