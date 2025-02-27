WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(DISTINCT c.Id) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Tags, u.DisplayName
),
TopRanked AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 -- Top 5 posts per tag
)
SELECT 
    TR.PostId,
    TR.Title,
    TR.CreationDate,
    TR.OwnerDisplayName,
    TR.CommentCount,
    TR.AnswerCount,
    TR.UpVoteCount,
    TR.DownVoteCount,
    STUFF((
        SELECT 
            ',' + TAG.TagName
        FROM 
            Tags TAG
        WHERE 
            TR.Tags LIKE '%' + TAG.TagName + '%' 
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS RelatedTags
FROM 
    TopRanked TR
ORDER BY 
    TR.UpVoteCount DESC, TR.CreationDate DESC;
