WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        u.DisplayName AS AuthorName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN 
        Tags t ON t.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) 
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        VoteCount DESC
    LIMIT 5
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    rp.AuthorName,
    rp.Reputation,
    ph.EditCount,
    ph.LastEditDate,
    mau.DisplayName AS MostActiveUser,
    mau.VoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories ph ON rp.Id = ph.PostId
LEFT JOIN 
    MostActiveUsers mau ON mau.VoteCount = (
        SELECT 
            MAX(VoteCount) 
        FROM 
            MostActiveUsers 
    )
WHERE 
    rp.TagRank <= 3 -- Get top 3 recent posts per tag
ORDER BY 
    rp.CreationDate DESC;
