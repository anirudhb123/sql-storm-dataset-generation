WITH PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.Value) AS TotalVotes,
        COALESCE(MAX(pc.Comment), 'No comments') AS LastComment,
        MIN(CASE WHEN ph.PostHistoryTypeId = 1 THEN ph.CreationDate END) AS FirstTitleChange
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments pc ON pc.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),

RankedPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.TotalVotes DESC, pd.AnswerCount DESC) AS PostRank
    FROM 
        PostDetail pd
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.AnswerCount,
    rp.TotalVotes,
    rp.LastComment,
    rp.FirstTitleChange,
    ARRAY_AGG(DISTINCT TRIM(UNNEST(string_to_array(rp.Tags, '>')))::varchar) ORDER BY TRIM(UNNEST(string_to_array(rp.Tags, '>'))) ASC) AS UniqueTags
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerName, rp.AnswerCount, rp.TotalVotes, rp.LastComment, rp.FirstTitleChange
ORDER BY 
    rp.PostRank;
