WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(com.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments com ON p.Id = com.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        tu.UserId,
        tu.DisplayName AS UserDisplayName,
        tu.QuestionCount,
        tu.AnswerCount
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON rp.PostRank = 1 AND rp.OwnerUserId = tu.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    COALESCE(pd.Score, 0) AS EffectiveScore,
    COALESCE(pd.ViewCount, 0) AS TotalViews,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.UserDisplayName,
    CASE 
        WHEN pd.QuestionCount > 0 THEN 'Question Maker' 
        ELSE 'Answer Provider' 
    END AS UserRole
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.TotalViews DESC;
