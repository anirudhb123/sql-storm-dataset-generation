WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(arr.TagCount, 0) AS TagCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TagCount
        FROM 
            unnest(string_to_array(Tags, '>')) AS tag
        GROUP BY 
            PostId
    ) arr ON p.Id = arr.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Counting only Upvotes
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, arr.TagCount, c.CommentCount
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        OwnerName,
        TagCount, 
        CommentCount, 
        VoteCount,
        RANK() OVER (ORDER BY VoteCount DESC, CreationDate ASC) AS VoteRank
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 -- Top 5 posts per user
)
SELECT 
    FP.*,
    PH.UserDisplayName AS LastEditorName,
    PH.CreationDate AS LastEditDate,
    PH.Comment AS EditComment,
    PH.Text AS RawText
FROM 
    FilteredPosts FP
LEFT JOIN 
    PostHistory PH ON FP.PostId = PH.PostId
    AND PH.PostHistoryTypeId IN (4, 5, 6) -- Fetching title/body/tag edits
WHERE 
    PH.CreationDate = (
        SELECT MAX(PH2.CreationDate)
        FROM PostHistory PH2
        WHERE PH2.PostId = FP.PostId
          AND PH2.PostHistoryTypeId IN (4, 5, 6)
    )
ORDER BY 
    VoteCount DESC, CreationDate DESC;
